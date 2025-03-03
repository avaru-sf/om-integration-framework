public interface IRequestBodyPreparer {
    Map<String, Object> prepareRequestBody(Map<String, Object> data);
}